/**
 * 文本替换脚本
 * 替换网页文本，支持原文/译文/对照模式切换
 * 
 * 关键设计：只操作元素的直接文本节点（TEXT_NODE），
 * 保留子元素结构不被破坏。
 */

(function() {
    'use strict';
    
    /**
     * 获取元素的所有直接文本节点内容（拼接）
     */
    function _getDirectText(element) {
        let text = '';
        for (const child of element.childNodes) {
            if (child.nodeType === Node.TEXT_NODE) {
                text += child.textContent;
            }
        }
        return text;
    }
    
    /**
     * 设置元素的直接文本节点内容
     * 第一个文本节点获得全部文本，其余文本节点清空。
     * 如果没有文本节点，在开头创建一个。
     */
    function _setDirectTextNodes(element, text) {
        let hasTextNode = false;
        for (const child of element.childNodes) {
            if (child.nodeType === Node.TEXT_NODE) {
                if (!hasTextNode) {
                    child.textContent = text;
                    hasTextNode = true;
                } else {
                    child.textContent = '';
                }
            }
        }
        if (!hasTextNode) {
            element.insertBefore(document.createTextNode(text), element.firstChild);
        }
    }
    
    /**
     * HTML转义
     */
    function escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }
    
    /**
     * 替换文本内容
     */
    function replaceTextContent(translations) {
        if (!Array.isArray(translations)) return;
        
        let replacedCount = 0;
        
        translations.forEach(item => {
            if (!item || !item.id || !item.text) return;
            
            const element = document.getElementById(item.id);
            if (!element) return;
            
            // 保存原文（仅直接文本节点内容，尚未保存时）
            if (!element.hasAttribute('data-wl-original')) {
                element.setAttribute('data-wl-original', _getDirectText(element));
            }
            
            // 保存译文
            element.setAttribute('data-wl-translated', item.text);
            
            // 只替换直接文本节点，保留子元素
            _setDirectTextNodes(element, item.text);
            
            replacedCount++;
        });
        
        console.log('[LangFerry] 已替换 ' + replacedCount + ' 个文本节点');
        return replacedCount;
    }
    
    /**
     * 显示原文
     */
    function showOriginal() {
        const elements = document.querySelectorAll('[data-wl-original]');
        let count = 0;
        
        elements.forEach(el => {
            // 移除对照模式添加的wrapper
            const wrappers = el.querySelectorAll('[data-wl-bilingual]');
            wrappers.forEach(w => w.remove());
            
            const original = el.getAttribute('data-wl-original');
            if (original != null) {
                _setDirectTextNodes(el, original);
                count++;
            }
        });
        
        console.log('[LangFerry] 已切换到原文模式，共 ' + count + ' 个节点');
        return count;
    }
    
    /**
     * 显示译文
     */
    function showTranslated() {
        const elements = document.querySelectorAll('[data-wl-translated]');
        let count = 0;
        
        elements.forEach(el => {
            // 移除对照模式添加的wrapper
            const wrappers = el.querySelectorAll('[data-wl-bilingual]');
            wrappers.forEach(w => w.remove());
            
            const translated = el.getAttribute('data-wl-translated');
            if (translated != null) {
                _setDirectTextNodes(el, translated);
                count++;
            }
        });
        
        console.log('[LangFerry] 已切换到译文模式，共 ' + count + ' 个节点');
        return count;
    }
    
    /**
     * 显示对照模式
     * 在直接文本节点位置插入对照视图，保留子元素结构
     */
    function showBilingual() {
        const elements = document.querySelectorAll('[data-wl-original]');
        let count = 0;
        
        elements.forEach(el => {
            // 先移除旧的对照wrapper（避免重复添加）
            const oldWrappers = el.querySelectorAll('[data-wl-bilingual]');
            oldWrappers.forEach(w => w.remove());
            
            const original = el.getAttribute('data-wl-original');
            const translated = el.getAttribute('data-wl-translated');
            
            if (original != null && translated != null) {
                // 清除直接文本节点
                for (const child of el.childNodes) {
                    if (child.nodeType === Node.TEXT_NODE) {
                        child.textContent = '';
                    }
                }
                
                // 在元素开头插入对照视图
                const wrapper = document.createElement('span');
                wrapper.setAttribute('data-wl-bilingual', 'true');
                wrapper.style.display = 'block';
                wrapper.innerHTML = 
                    '<span style="color: #666; font-size: 0.85em; display: block; margin-bottom: 2px;">' + 
                    escapeHtml(original) + 
                    '</span>' +
                    '<span style="color: #333; display: block;">' + 
                    escapeHtml(translated) + 
                    '</span>';
                el.insertBefore(wrapper, el.firstChild);
                count++;
            }
        });
        
        console.log('[LangFerry] 已切换到对照模式，共 ' + count + ' 个节点');
        return count;
    }
    
    /**
     * 清除所有翻译
     */
    function clearTranslations() {
        const elements = document.querySelectorAll('[data-wl-original]');
        let count = 0;
        
        elements.forEach(el => {
            const original = el.getAttribute('data-wl-original');
            if (original != null) {
                _setDirectTextNodes(el, original);
            }
            
            // 移除对照模式添加的wrapper
            const bilingualWrappers = el.querySelectorAll('[data-wl-bilingual]');
            bilingualWrappers.forEach(w => w.remove());
            
            el.removeAttribute('data-wl-original');
            el.removeAttribute('data-wl-translated');
            count++;
        });
        
        console.log('[LangFerry] 已清除 ' + count + ' 个节点的翻译');
        return count;
    }
    
    /**
     * 获取当前显示模式
     */
    function getCurrentMode() {
        const firstElement = document.querySelector('[data-wl-original]');
        if (!firstElement) return 'none';
        
        // 检查是否有对照模式的wrapper
        if (firstElement.querySelector('[data-wl-bilingual]')) {
            return 'bilingual';
        }
        
        if (firstElement.getAttribute('data-wl-translated') != null &&
            _getDirectText(firstElement) === firstElement.getAttribute('data-wl-translated')) {
            return 'translated';
        }
        
        if (_getDirectText(firstElement) === firstElement.getAttribute('data-wl-original')) {
            return 'original';
        }
        
        return 'unknown';
    }
    
    /**
     * 获取翻译统计信息
     */
    function getTranslationStats() {
        const originalElements = document.querySelectorAll('[data-wl-original]');
        const translatedElements = document.querySelectorAll('[data-wl-translated]');
        
        return {
            totalNodes: originalElements.length,
            translatedNodes: translatedElements.length,
            currentMode: getCurrentMode()
        };
    }
    
    // 导出函数
    window.replaceTextContent = replaceTextContent;
    window.showOriginal = showOriginal;
    window.showTranslated = showTranslated;
    window.showBilingual = showBilingual;
    window.clearTranslations = clearTranslations;
    window.getCurrentMode = getCurrentMode;
    window.getTranslationStats = getTranslationStats;
    
    console.log('[LangFerry] 文本替换脚本已加载 v2');
})();
