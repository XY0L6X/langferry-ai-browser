/**
 * 文本提取脚本
 * 提取网页正文文本，按DOM节点ID返回结构化数据
 */

(function() {
    'use strict';
    
    // 忽略的标签（仅过滤纯功能/隐藏元素，保留可能有翻译价值的结构标签）
    const IGNORED_TAGS = [
        'SCRIPT', 'STYLE', 'NOSCRIPT', 'IFRAME', 'OBJECT', 'EMBED',
        'BUTTON', 'INPUT', 'SELECT', 'TEXTAREA', 'FORM', 'LABEL',
        'SVG', 'CANVAS', 'VIDEO', 'AUDIO', 'SOURCE', 'TRACK'
    ];
    
    // 忽略的类名（仅过滤纯广告，不过滤可能有翻译内容的类）
    const IGNORED_CLASSES = [
        'ad', 'advertisement', 'sponsored'
    ];
    
    /**
     * 检查元素是否应该被忽略
     */
    function isIgnoredElement(element) {
        if (!element || !element.tagName) return true;
        
        // 检查标签
        if (IGNORED_TAGS.includes(element.tagName)) return true;
        
        // 检查类名
        const classList = element.classList;
        for (const cls of IGNORED_CLASSES) {
            if (classList.contains(cls)) return true;
        }
        
        // 检查隐藏元素
        const style = window.getComputedStyle(element);
        if (style.display === 'none' || style.visibility === 'hidden') return true;
        
        // 检查aria-hidden
        if (element.getAttribute('aria-hidden') === 'true') return true;
        
        return false;
    }
    
    /**
     * 生成唯一ID
     */
    function generateNodeId(element) {
        if (element.id) return element.id;
        
        // 生成随机ID
        const id = 'wl_' + Math.random().toString(36).substr(2, 9);
        element.id = id;
        return id;
    }
    
    /**
     * 检查文本是否有效
     */
    function isValidText(text) {
        if (!text) return false;
        
        const trimmed = text.trim();
        
        // 太短的文本（1个字符也可能是需要翻译的标签/标题）
        if (trimmed.length < 1) return false;
        
        // 纯数字
        if (/^\d+$/.test(trimmed)) return false;
        
        // 纯标点符号
        if (/^[\s\p{P}]+$/u.test(trimmed)) return false;
        
        // 纯空白字符
        if (/\s/.test(trimmed) && trimmed.length < 5) return false;
        
        return true;
    }
    
    /**
     * 提取文本内容
     * 返回元素节点（不是文本节点），这样replaceText才能通过ID找到它们
     */
    function extractTextContent() {
        const textNodes = [];
        const seenTexts = new Set();
        
        // 遍历所有可能有文本内容的元素（扩展选择器覆盖更多场景）
        const allElements = document.querySelectorAll(
            'p, h1, h2, h3, h4, h5, h6, span, div, li, a, td, th, ' +
            'strong, em, b, i, u, small, pre, code, blockquote, ' +
            'figcaption, caption, dt, dd, summary, label, cite, time, ' +
            'article, section, main, nav, header, footer, aside, abbr'
        );
        
        allElements.forEach(element => {
            // 仅检查元素本身（不过滤祖先链，避免误伤内容区域）
            if (isIgnoredElement(element)) return;
            
            // 获取直接文本内容（不包括子元素的文本）
            let directText = '';
            for (const child of element.childNodes) {
                if (child.nodeType === Node.TEXT_NODE) {
                    directText += child.textContent;
                }
            }
            
            const text = directText.trim();
            
            // 检查文本有效性
            if (!isValidText(text)) return;
            
            // 检查是否重复
            if (seenTexts.has(text)) return;
            
            seenTexts.add(text);
            
            // 生成或获取元素ID
            const id = generateNodeId(element);
            
            textNodes.push({
                id: id,
                text: text,
                tag: element.tagName.toLowerCase()
            });
        });
        
        return textNodes;
    }
    
    /**
     * 获取网页标题
     */
    function getPageTitle() {
        return document.title || '';
    }
    
    /**
     * 获取网页语言
     */
    function getPageLanguage() {
        return document.documentElement.lang || 'auto';
    }
    
    // 导出函数
    window.extractTextContent = extractTextContent;
    window.getPageTitle = getPageTitle;
    window.getPageLanguage = getPageLanguage;
    
    console.log('[LangFerry] 文本提取脚本已加载');
})();